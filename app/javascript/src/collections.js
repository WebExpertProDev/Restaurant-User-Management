import React from "react";
import {
  List,
  Edit,
  SimpleForm,
  TextInput,
  DateField,
  BooleanField,
  NumberField,
  Datagrid,
  TextField,
} from "react-admin";

export const CollectionsList = (props) => (
  <List {...props}>
    <Datagrid rowClick="edit">
      <TextField source="id" />
      <TextField source="user_id" />
      <TextField source="partner" />
      <DateField source="reservation_date" />
      <DateField source="created_at" />
      <TextField source="confirmation_id" label="Confirmation ID" />
      <NumberField source="cover" label="Cover" />
      <BooleanField source="is_past" label="Is Past" />
    </Datagrid>
  </List>
);

export const CollectionsEdit = (props) => (
  <Edit {...props}>
    <SimpleForm>
      <TextInput disabled source="id" />
      <TextInput source="name" />
      <TextInput source="number" label="Phone Number" />
      <TextInput source="email" label="Email" />
    </SimpleForm>
  </Edit>
);

export default CollectionsList;
